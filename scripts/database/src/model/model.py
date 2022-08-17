# from jinja2.nodes import For
from sqlalchemy import Column, Text, Integer, ForeignKey, Index
from sqlalchemy.orm import relation, relationship
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.sql.sqltypes import String
Base = declarative_base()
prefix = 'nin_'


class Language(Base):
    '''Table defining supported languages - alle tables ending with 'Info'
    reference this table.'''

    __tablename__ = f'{prefix}Language'
    pid = Column(Integer, autoincrement=True, primary_key=True)
    _id = Column(Text)
    name = Column(Text)


class Detail(Base):
    '''Key value pairs for details'''

    __tablename__ = f'{prefix}Detail'
    pid = Column(Integer, autoincrement=True, primary_key=True)
    _id = Column(Text, index=True)
    language_id = Column(Text, ForeignKey(
        f'{prefix}Language._id'))
    key = Column(Text, index=True)
    value = Column(Text)
    __table_args__ = (Index('detail_index', "_id", "language_id", "key"), )


class MajorTypeGroup(Base):
    '''Table of Major type groups lie T,V,M etc..'''

    __tablename__ = f'{prefix}MajorTypeGroup'
    pid = Column(Integer, autoincrement=True, primary_key=True)
    _id = Column(Text, unique=True)
    detail_id = Column(Text, ForeignKey(f'{prefix}Detail._id'))

    # References
    majorType = relationship('MajorType', back_populates='majorTypeGroup')



class MajorType(Base):
    '''Major types like T4,V11 and so on, references major type.'''

    __tablename__ = f'{prefix}MajorType'
    pid = Column(Integer, autoincrement=True, primary_key=True)
    _id = Column(Text, unique=True,)
    majorTypeGroup_id = Column(Text, ForeignKey(f'{prefix}MajorTypeGroup._id'))
    order = Column(Integer)
    detail_id = Column(Text, ForeignKey(f'{prefix}Detail._id'))

    # References
    majorTypeGroup = relationship('MajorTypeGroup', back_populates='majorType')
    lec = relationship('MajorTypeLEC', back_populates='majorType')


class MinorType(Base):
    '''Minor types like T4-1 '''

    __tablename__ = f'{prefix}MinorType'
    pid = Column(Integer, autoincrement=True, primary_key=True)
    _id = Column(Text, unique=True)
    majorType_id = Column(Text, ForeignKey(f'{prefix}MajorType._id'), index=True)
    detail_id = Column(Text, ForeignKey(f'{prefix}Detail._id'))

    # References
    standardSegments = relationship('MinorTypeStandardSegment')
    minorTypeScaled = relationship('MinorTypeScaled')


class MinorTypeStandardSegment(Base):
    '''Minor type association with standard segments and Minor types'''

    __tablename__ = f'{prefix}MinorTypeStandardSegment'
    pid = Column(Integer, autoincrement=True, primary_key=True)
    minorType_id = Column(Text, ForeignKey(
        f'{prefix}MinorType._id'), index=True)
    standardSegment_id = Column(Text, ForeignKey(
        f'{prefix}StandardSegment._id'))

    # References
    minorType = relationship('MinorType', back_populates='standardSegments')
    standardSegment = relationship('StandardSegment')


class MinorTypeScaled(Base):
    '''Minor type association with scale'''

    __tablename__ = f'{prefix}MinorTypeScaled'
    pid = Column(Integer, autoincrement=True, primary_key=True)
    _id = Column(Text)
    minorType_id = Column(Text, ForeignKey(
        f'{prefix}MinorType._id'), index=True)
    mappingScale_id = Column(Integer, ForeignKey(f'{prefix}MappingScale._id'))
    detail_id = Column(Text, ForeignKey(f'{prefix}Detail._id'))
    is_implemented = Column(Integer, default=0)

    __table_args__ = (Index('MinorTypeScaled_index', "minorType_id", "mappingScale_id"), )

    # References
    minorType = relationship('MinorType', back_populates='minorTypeScaled')


class MappingScale(Base):
    '''Mapping scale used'''

    __tablename__ = f'{prefix}MappingScale'
    pid = Column(Integer, autoincrement=True, primary_key=True)
    _id = Column(Integer, unique=True)
    name = Column(Text)


class LEC(Base):
    '''Local environmental complex-gradients with their descriptions'''

    __tablename__ = f'{prefix}LEC'
    pid = Column(Integer, autoincrement=True, primary_key=True)
    _id = Column(Text, unique=True, index=True)
    parentLec_id = Column(Text, ForeignKey(f'{prefix}LEC._id'))
    structuringProcess_id = Column(
        Text, ForeignKey(f'{prefix}StructuringProcess._id'))
    patternOfVariation_id = Column(
        Text, ForeignKey(f'{prefix}PatternOfVariation._id'))
    knowledgeBaseRelations = Column(Integer)
    knowledgeBaseDivision = Column(Integer)
    spatialScale = Column(Integer)
    detail_id = Column(Text, ForeignKey(f'{prefix}Detail._id'))

    # References
    childLec = relationship('LEC', back_populates='parentLec')
    parentLec = relationship('LEC')
    # elementarySegment = relationship('ElementarySegment', back_populates='lec')
    structuringProcess = relationship(
        'StructuringProcess', back_populates='lec')
    patternOfVariation = relationship(
        'PatternOfVariation', back_populates='lec')
    majorType = relationship('MajorTypeLEC', back_populates='lec')


class StructuringProcess(Base):
    '''category of structuring process of local environmental complex-gradient'''

    __tablename__ = f'{prefix}StructuringProcess'
    pid = Column(Integer, autoincrement=True, primary_key=True)
    _id = Column(Text, unique=True)
    detail_id = Column(Text, ForeignKey(f'{prefix}Detail._id'))

    # References
    lec = relationship('LEC', back_populates='structuringProcess')


class PatternOfVariation(Base):
    '''pattern of variation (f = factor; g = gradient, ga = gradient that
    ends in a species-thinning situation at high intensity)'''

    __tablename__ = f'{prefix}PatternOfVariation'
    pid = Column(Integer, autoincrement=True, primary_key=True)
    _id = Column(Text, unique=True)
    detail_id = Column(Text, ForeignKey(f'{prefix}Detail._id'))

    # References
    lec = relationship('LEC', back_populates='patternOfVariation')


class MajorTypeLEC(Base):
    '''Association table for LEC and major types'''

    __tablename__ = f'{prefix}MajorTypeLEC'
    pid = Column(Integer, autoincrement=True, primary_key=True)
    _id = Column(Text, unique=True, index=True)
    lec_id = Column(Text, ForeignKey(f'{prefix}LEC._id'), index=True)
    majorType_id = Column(Text, ForeignKey(f'{prefix}MajorType._id'), index=True)
    lecType_id = Column(Text, ForeignKey(f'{prefix}LECType._id'))
    axis = Column(Integer)

    # References
    majorType = relationship('MajorType', back_populates='lec')
    lec = relationship('LEC', back_populates='majorType')
    standardSegment = relationship('StandardSegment')


class LECType(Base):
    ''' LEC categories types like dLEC, mLEC, iLEC and so on'''

    __tablename__ = f'{prefix}LECType'
    pid = Column(Integer, autoincrement=True, primary_key=True)
    _id = Column(Text, unique=True)
    detail_id = Column(Text, ForeignKey(f'{prefix}Detail._id'))


class ElementarySegment(Base):
    __tablename__ = f'{prefix}ElementarySegment'
    pid = Column(Integer, autoincrement=True, primary_key=True)
    _id = Column(Text, unique=True, index=True)
    lec_id = Column(Text, ForeignKey(f'{prefix}LEC._id'))
    value = Column(Text)
    order = Column(Integer)


class ElementarySegmentGroup(Base):
    __tablename__ = f'{prefix}ElementarySegmentGroup'
    pid = Column(Integer, autoincrement=True, primary_key=True)
    _id = Column(Text, index=True)
    elementarySegment_id = Column(Text, ForeignKey(
        f'{prefix}ElementarySegment._id'), index=True)
    majorType_id = Column(Text, ForeignKey(f'{prefix}MajorType._id'), index=True)
    lec_id = Column(Text, ForeignKey(f'{prefix}LEC._id'), index=True)
    standardSegment_id = Column(Text, ForeignKey(
        f'{prefix}StandardSegment._id'), index=True)

    __table_args__ = (Index('ElementarySegmentGroup_index', "standardSegment_id", "majorType_id"), )


class ElementarySegmentGroupDetail(Base):
    '''elementary segments of individual LECs like KA.a, VT.b'''

    __tablename__ = f'{prefix}ElementarySegmentGroupDetail'
    pid = Column(Integer, autoincrement=True, primary_key=True)
    elementarySegmentGroup_id = Column(Text, ForeignKey(
        f'{prefix}ElementarySegmentGroup.elementarySegment_id'), unique=True, index=True)
    lec_id = Column(Text, ForeignKey(f'{prefix}LEC._id'))
    value = Column(Text)
    detail_id = Column(Text, ForeignKey(f'{prefix}Detail._id'))

    # References
    # lec = relationship('LEC', back_populates='elementarySegment')


class StandardSegmentElement(Base):
    ''' Association table that connects standard segments and elementary segments'''

    __tablename__ = f'{prefix}StandardSegmentElement'
    pid = Column(Integer, autoincrement=True, primary_key=True)
    standardSegment_id = Column(Text, ForeignKey(
        f'{prefix}StandardSegment._id'), index=True)
    elementarySegment_id = Column(Text, ForeignKey(
        f'{prefix}ElementarySegment._id'))

    # References
    elementarySegment = relationship('ElementarySegment')
    standardSegment = relationship(
        'StandardSegment', back_populates='elementarySegment')


class StandardSegment(Base):
    ''' Standard segments for LACCategorie. They consist of Elementary segments'''

    __tablename__ = f'{prefix}StandardSegment'
    pid = Column(Integer, autoincrement=True, primary_key=True)
    _id = Column(Text, unique=True, index=True)
    majorTypeLEC_id = Column(Text, ForeignKey(f'{prefix}MajorTypeLEC._id'), index=True)
    order = Column(Integer)
    detail_id = Column(Text, ForeignKey(f'{prefix}Detail._id'))
    lec_id = Column(Text, ForeignKey(f'{prefix}LEC._id'))
    majorType_id = Column(Text, ForeignKey(f'{prefix}MajorType._id'), index=True)
    selected = Column(Integer)

    # References
    elementarySegment = relationship('StandardSegmentElement')
    majorTypeLEC = relationship(
        'MajorTypeLEC', back_populates='standardSegment')


class GadValue(Base):
    __tablename__ = f'{prefix}GadValue'
    pid = Column(Integer, autoincrement=True, primary_key=True)
    elementarySegmentCombination_id = Column(Text, ForeignKey(
        f'{prefix}ElementarySegmentCombination._id'))
    species_id = Column(Integer, ForeignKey(
        f'{prefix}Species.scientificNameId'), index=True)
    majorType_id = Column(Text, ForeignKey(f'{prefix}MajorType._id'))
    valueM7Scale_id = Column(Integer, ForeignKey(
        f'{prefix}GadScale.m7Scale'), nullable=True)
    valueM3Scale_id = Column(Integer, ForeignKey(
        f'{prefix}GadScale.m3Scale'), nullable=True)
    # valueModifier = Column(Integer, nullable=True)
    # lecCombination_id = Column(Integer, ForeignKey(f'{prefix}LECCombination._id'))

    # References
    # elementarySegment = relationship(
    #     'GadValueElementarySegment', back_populates='gadValue')


class GadModifier(Base):
    '''uLKM value'''
    __tablename__ = f'{prefix}GadModifier'
    pid = Column(Integer, autoincrement=True, primary_key=True)
    majorTypeLEC_id = Column(
        Text,
        ForeignKey(f'{prefix}MajorTypeLEC._id'),

    )
    majorType_id = Column(
        Text,
        ForeignKey(f'{prefix}MajorType._id'),
    )
    lec_id = Column(
        Text,
        ForeignKey(f'{prefix}LEC._id')
    )
    species_id = Column(Integer, ForeignKey(
        f'{prefix}Species.scientificNameId'), index=True)
    value = Column(Integer)


class ElementarySegmentCombination(Base):
    __tablename__ = f'{prefix}ElementarySegmentCombination'
    pid = Column(Integer, autoincrement=True, primary_key=True)
    _id = Column(Text, index=True)
    elementarySegmentGroup_id = Column(Text, ForeignKey(
        f'{prefix}ElementarySegmentGroup._id'))
    majorTypeLEC_id = Column(
        Text,
        ForeignKey(f'{prefix}MajorTypeLEC._id')
    )

    # References
    # gadValue = relationship('GadValue', back_populates='elementarySegment')


class GadScale(Base):
    ''' Collection of M7 and M3 scales with constancy'''

    __tablename__ = f'{prefix}GadScale'
    pid = Column(Integer, autoincrement=True, primary_key=True)
    m7Scale = Column(Integer, unique=True)
    m3Scale = Column(Integer)
    Constancy = Column(Text)


class Species(Base):
    __tablename__ = f'{prefix}Species'
    pid = Column(Integer, autoincrement=True, primary_key=True)
    scientificNameId = Column(Integer, unique=True, index=True)
    scientificName = Column(Text, index=True)
    author = Column(Text)
    vernacularName = Column(Text, index=True)

class InferenceSpecies(Base):
    __tablename__ = f'{prefix}InferenceSpecies'
    gbif_id = Column(Integer, primary_key=True)
    name_latin = Column(Text)
    name_nb = Column(Text)
    
    

class InferenceTypes(Base):
    __tablename__ = f'{prefix}InferenceTypes'
    pid = Column(Integer, autoincrement=True, primary_key=True)
    minorTypeScaled_id = Column(Text, ForeignKey(
        f'{prefix}MinorTypeScaled._id'), index=True)
    full_code = Column(Text)
    gbif_id = Column(Integer, ForeignKey(
        f'{prefix}InferenceSpecies.gbif_id'), index=True)
    code = Column(Text)